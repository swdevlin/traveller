class Api::JumpLogsController < Api::BaseController
  def index
    @jumps = JumpLog.all.order(arrive_year: :desc, arrive_day: :desc)
  end
end
