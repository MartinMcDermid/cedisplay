class IndexController < ApplicationController
	helper_method :row_color, :table_half_agents
	def main
		@current_agents = Liveagent.all
		@agents_in_calls = @current_agents.where(status: "INCALL")
		@agents_waiting = @current_agents.where(status: "READY")
		@agents_paused = @current_agents.where(status: "PAUSED")

		@agent_details = Hash.new
		@current_agents.each do |a|
			@agent_details["#{a.user}"] = { :name => User.where(user: a.user).pluck(:full_name).first, :status => a.status, :time => time_in_status(a) }#, :interviews => interviews(a.user), :interviews_offgrid => interviews_offgrid(a.user), :appointments_made => appointments_made }
		@agents_interviews = Hash.new
		@current_agents.each do |a|
                        @agents_interviews["#{a.user}"] = { :name => User.where(user: a.user).pluck(:full_name).first, :interviews => interviews(a.user), :appointments_made => appointments_made(a.user) }
                end
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
		@current_agents.each do |a|
			@agents_interviews["#{a.user}"] = { :name => User.where(user: a.user).pluck(:full_name).first, :interviews => interviews(a.user), :appointments_made => appointments_made(a.user) }
		end
	end

	private

	def interviews(user)
		@interviews = Log.where("user = '#{user}' and date(call_date) = curdate() and status in('INTC','INTCG')")
		@interviews.count
		
	end

	def interviews_offgrid(user)
		@interviews_offgrid = Log.where("user = '#{user}' and date(call_date) = curdate() and status = 'INTCG'")
		@interviews_offgrid.count
	end  
	
	def appointments_made(user)
		appointment_count = 0
		@interviews = Log.where("user = '#{user}' and date(call_date) = curdate() and status in('INTC','INTCG')")
		@interviews.pluck(:lead_id).each do |lead|
			if List.where(lead_id: lead).pluck(:status) == "APP"
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
