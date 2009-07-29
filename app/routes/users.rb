class Main
  get "/users/:username" do
    @user = User.find(:username, params[:username]).first
    @posts_authored = top(@user.posts_authored)
    @posts_voted = top(@user.votes)

    haml :"users/username"
  end
end
