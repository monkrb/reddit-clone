class Main
  get "/" do
    @date = params[:date] ? Date.parse(params[:date]) : Date.today

    @just_added = Post.just_added

    # Grab today's posts.
    @today = Post.top_for(format_date(@date))

    # Grab yesterday's posts.
    @yesterday = Post.top_for(format_date(@date - 1))

    haml :"home"
  end

  get '/date/:year/:month/:day' do |year, month, day|
    @date = "#{month}/#{day}/#{year}"
    @posts = Post.find(:date, @date)

    haml :"date/year/month/day"
  end
end
