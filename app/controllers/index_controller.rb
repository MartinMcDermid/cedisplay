class IndexController < ApplicationController
	helper_method :row_color
	def main
		@current_agents = Liveagent.all
		@agents_in_calls = @current_agents.where(status: "INCALL")
		@agents_waiting = @current_agents.where(status: "READY")
		@agents_paused = @current_agents.where(status: "PAUSED")
		@live_agents = Liveagent.all

		@agent_details = Hash.new
		@current_agents.each do |a|
			@agent_details["#{a.user}"] = { :name => User.where(user: a.user).pluck(:full_name).first, :status => a.status, :time => time_in_status(a) }#, :interviews => interviews(a.user), :interviews_offgrid => interviews_offgrid(a.user), :appointments_made => appointments_made }
		end
			
	end

	private

	def interviews(user)
		@interviews = Log.where("user = '#{user}' and date(call_date) = curdate() and status = 'INTC'")
		@interviews.count
		
	end

	def interviews_offgrid(user)
		@interviews_offgrid = Log.where("user = '#{user}' and date(call_date) = curdate() and status = 'INTCG'")
		@interviews_offgrid.count
	end  
	
	def appointments_made
		interviews_all = @interviews.merge(@interviews_offgrid)
		appointment_count = 0
		@interviews.each do |lead|
			if Lead.where(lead_id: lead.lead_id).pluck(:status) == "APP"
				appointment_count += 1
			end
		end
		@interviews_offgrid.each do |lead|
			if Lead.where(lead_id: lead.lead_id).pluck(:status) == "APP"
				appointment_count += 1
			end
		end
		appointment_count
	end

	def time_in_status(user_row)
		time = (DateTime.now.to_i - user_row.last_state_change.to_i)
		@time = Time.at(time).gmtime.strftime('%M:%S')
	end

	def row_color(status)
		color = ''
		if status == "READY"
			if @time < '00:59'
				color = "#ADD8E6"
			elsif @time > '01:00' and @time < '5:00'
				color = "blue"
			else
				color = "#191970"
			end
		elsif status == "INCALL"
			color = "white"
			if @time < "00:06"
				color = "#D8BFD8"
			elsif @time > "00:05" and @time < "0:59"
				color = "#EE82EE"
			else
				color = "purple"
			end
		elsif status == "PAUSED"
			color = "#F0E68C"
		end
		color
	end
	
end
