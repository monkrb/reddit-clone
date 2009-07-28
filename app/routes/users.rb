class Main
  get "/users/:username" do
    @user = User.find(:username, params[:username]).first
    @posts = @user.posts

    haml :"users/username"
  end
end
