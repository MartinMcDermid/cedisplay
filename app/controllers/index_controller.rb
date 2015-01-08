class IndexController < ApplicationController
	helper_method :row_color, :table_half_agents, :latest_interview_color

	def main
		#### First initiation of variables used in both status and interviews
		## This part defines whether top bar shows agent details or call details
		session[:top_bar_counter] = 1
		@top_bar_type = 'agents'

		@calls_being_placed = Autocall.where.not(status: 'XFER')
		@calls_ringing = Autocall.where(status: 'SENT')
		@calls_waiting_for_agents = Autocall.where(status: 'LIVE')
		@calls_in_IVR = Autocall.where(status: 'IVR')

		@current_agents = Liveagent.all # Used in status and interviews
		@agents_in_calls = @current_agents.where(status: "INCALL") # Status only
		@agents_waiting = @current_agents.where(status: "READY") # Status only
		@agents_paused = @current_agents.where(status: "PAUSED") # Status only
		
		#### Initiate variables for the partials for the first time, after that, they get initiated in their respective partial methods
		
		## status partial init
		@agent_details = Hash.new
		@current_agents.each do |a|
			@agent_details["#{a.user}"] = { :name => User.where(user: a.user).pluck(:full_name).first, :status => a.status, :time => time_in_status(a) }
			# the time_in_status is in seconds because it's easier to parse it when it comes to coloring
		end

		## interviews partial init
		@interviews = interviews_in_shift(Log.where("date(call_date) = curdate() and status in('INTC','INTCG')").pluck(:lead_id, :user, :status, :call_date)).sort { |a,b| b[3] <=> a[3] }
		@interviews_total = Log.where("date(call_date) = curdate() and status in('INTC','INTCG')").count
		@agents_interviews = Hash.new
		@interviews.each do |a|
			@agents_interviews["#{a[1]}"] = { :name => User.where(user: a[1]).pluck(:full_name).first, :interviews => interviews(a[1]) }#, :appointments_made => appointments_made(a.user) }  
		end
		if !@interviews.blank?
			@timediff = TimeDifference.between(@interviews.first[3], Time.now).in_seconds.to_i
		end
	end

	### This method is called by the javascript (status_partial.js) which refreshes the status tables in the main view
	def status_partial
		if session[:top_bar_counter] < 4
			session[:top_bar_counter] += 1
			@top_bar_type = 'agents'
		elsif session[:top_bar_counter] > 3 and session[:top_bar_counter] < 7
			@top_bar_type = 'calls'
			session[:top_bar_counter] += 1
		else
			session[:top_bar_counter] = 1
			@top_bar_type = 'agents'
		end

		@calls_being_placed = Autocall.where.not(status: 'XFER')
		@calls_ringing = Autocall.where(status: 'SENT')
		@calls_waiting_for_agents = Autocall.where(status: 'LIVE')
		@calls_in_IVR = Autocall.where(status: 'IVR')

		@current_agents = Liveagent.all
		@agent_details = Hash.new
		@agents_in_calls = @current_agents.where(status: "INCALL")
		@agents_waiting = @current_agents.where(status: "READY")
		@agents_paused = @current_agents.where(status: "PAUSED")
		@current_agents.each do |a|
			@agent_details["#{a.user}"] = { :name => User.where(user: a.user).pluck(:full_name).first, :status => a.status, :time => time_in_status(a) }
		end
		render partial: 'statustables'	
	end

	### This method is called by the javascript (status_partial.js) which refreshes the status tables in the main view
	def interviews_partial
		@current_agents = Liveagent.all
		@agents_interviews = Hash.new
		@interviews = interviews_in_shift(Log.where("date(call_date) = curdate() and status in('INTC','INTCG')").pluck(:lead_id, :user, :status, :call_date)).sort {|a,b| b[3] <=> a[3]}
		@interviews_total = Log.where("date(call_date) = curdate() and status in('INTC','INTCG')").count
		
		@interviews.each do |a|
			@agents_interviews["#{a[1]}"] = { :name => User.where(user: a[1]).pluck(:full_name).first, :interviews => interviews(a[1]) }
		end
		render partial: 'interviewstable'
		if !@interviews.blank?
			@timediff = TimeDifference.between(@interviews.first[3], Time.now).in_seconds.to_i
		end
	end

	private
	
	def interviews(user)
		completed = 0
		@interviews.each do |lead|
			# The lead is an array of 2 elements : a lead_id, :user, and :status
			if lead[1] == user
				completed += 1
			end
		end
		completed
	end  
	
	def appointments_made(user)
		appointment_count = 0
		@interviews.pluck(:lead_id).each do |lead|
			if Lead.where(lead_id: lead).pluck(:status) == "APP"
				appointment_count += 1
			end
		end
		appointment_count
	end

	def time_in_status(user_row)
		time = (user_row.last_update_time.to_i - user_row.last_state_change.to_i)
		#@time_i = Time.at(time).to_i
		#@time = Time.at(time).gmtime.strftime('%M:%S')
	end

	def row_color(status, time)
		status = status.to_s
		time = time.to_i
		color = "white"
		if status == "READY"
			color = "#ADD8E6"
			if time > 60 and time < 301
				color = "blue"
			elsif time > 300
				color = "#191970"
			end
		elsif status == "INCALL"
			color = "white"
			if time > 10 and time < 61
				color = "#D8BFD8"
			elsif time > 60 and time < 301
				color = "#EE82EE"
			elsif time > 300
				color = "purple"
			end
		elsif status == "PAUSED"
			color = "white"
			if time > 10 and time < 61
				color = "#F0E68C"
			elsif time > 60 and time < 301
				color = "yellow"
			elsif time > 300
				color = "#808000"
			end
		else
			color = "white"
		end
		color
	end

	def latest_interview_color(time_difference)
		if time_difference
			if time_difference < 60
				div_color = "background-color: #E0FFE0;border-color: green;"
			else
				div_color = ""
			end
		end
	end

	def interviews_in_shift(array)
		time_at_12_30 = Time.gm(Date.today.year, Date.today.month, Date.today.day, 12, 30)
		time_at_12_50 = Time.gm(Date.today.year, Date.today.month, Date.today.day, 12, 50)
		time_at_13_00 = Time.gm(Date.today.year, Date.today.month, Date.today.day, 13)
		time_at_16_00 = Time.gm(Date.today.year, Date.today.month, Date.today.day, 16)
		time_at_16_50 = Time.gm(Date.today.year, Date.today.month, Date.today.day, 16, 50)
		time_at_17_00 = Time.gm(Date.today.year, Date.today.month, Date.today.day, 17)
		time_at_20_00 = Time.gm(Date.today.year, Date.today.month, Date.today.day, 20)
=begin
		if Time.now.wday.between?(1, 4) # monday to thursday
			if Time.now < time_at_13_00
				array
			elsif Time.now > time_at_13_00 and Time.now < time_at_17_00
				array.select{ |leadid, user, status, calldate| calldate > time_at_12_30 }
			elsif Time.now > time_at_17_00
				array = array.select{ |leadid, user, status, calldate| calldate > time_at_16_00 }
			end
		elsif Time.now.wday == 5 # friday
			if Time.now < time_at_12_30
			elsif Time.now > time_at_12_30 and Time.now < time_at_16_00
				array = array.select{ |leadid, user, status, calldate| calldate > time_at_12_30 }
			elsif
				array = array.select{ |leadid, user, status, calldate| calldate > time_at_16_00 }
			end
		end
=end
		if Time.now < time_at_12_50
			#do nothing, full array returned
		elsif Time.now > time_at_12_50 and Time.now < time_at_16_50
			array = array.select{ |leadid, user, status, calldate| calldate > time_at_13_00 }
		elsif Time.now > time_at_16_50
			array = array.select{ |leadid, user, status, calldate| calldate > time_at_17_00 }
		end
		array
	end
end
