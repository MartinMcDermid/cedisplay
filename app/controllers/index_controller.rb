class IndexController < ApplicationController
	helper_method :row_color, :table_half_agents
	def main
		#### First initiation of variables used in both status and interviews
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
		@interviews = Log.where("date(call_date) = curdate() and status in('INTC','INTCG')").pluck(:lead_id, :user, :status, :call_date).sort  { |a, b| b[3] <=> a[3] }
		
		@agents_interviews = Hash.new
		@interviews.each do |a|
			@agents_interviews["#{a[1]}"] = { :name => User.where(user: a[1]).pluck(:full_name).first, :interviews => interviews(a[1]) }#, :appointments_made => appointments_made(a.user) }  
		end
	end

	def status_partial
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

	def interviews_partial
		@current_agents = Liveagent.all
		@agents_interviews = Hash.new
		@interviews = Log.where("date(call_date) = curdate() and status in('INTC','INTCG')").pluck(:lead_id, :user, :status, :call_date)
		# The below is commented to speed up the code execution. Uncomment in production to enable the interviews count
		@interviews.each do |a|
			@agents_interviews["#{a[1]}"] = { :name => User.where(user: a[1]).pluck(:full_name).first, :interviews => interviews(a[1]) }#, :appointments_made => appointments_made(a.user) }
		end
		render partial: 'interviewstable'
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
end
