# encoding: utf-8

class Main
  get "/posts/new" do
    @post = Post.new
    haml :"posts/new"
  end

  get "/posts/:id" do
    @post = Post[params[:id]]
    @author = User[@post.author]
    @url = @post.location
    haml :"posts/id"
  end

  post "/posts" do
    accept_login_or_signup

    @post = Post.new(params[:post])
    @post.author = current_user.id if current_user

    if @post.valid?
      @post.create
      session[:notice] = "Your link has been added"
      redirect "/"
    else
      haml :"posts/new"
    end
  end

  post "/posts/:id" do
    accept_login_or_signup

    @post = Post[params[:id]]
    current_user.vote_for(@post)
    redirect back
  end

  module Helpers
    def link_to_post(post)
      capture_haml do
        haml_tag(:a, post, :href => "/posts/#{post.id}", :title => post)
      end
    end

    def friendly_date(date)
      today = Date.today

      case date
      when today - 1
        "Yesterday"
      when today
        "Today"
      when today + 1
        "Tomorrow"
      else
        dow = DAYS[date.wday]

        if date.year == today.year
          if date.month == today.month
            "#{dow} #{date.strftime "%d"}"
          else
            "#{dow} #{date.strftime "%d/%m"}"
          end
        else
          "#{dow} #{date.strftime "%d/%m/%y"}"
        end
      end
    end

    def list(title, posts, message = "Nothing interesting here.")
      partial(:"posts/list", :title => title, :posts => posts, :message => message)
    end

    def top(posts)
      posts.sort_by(:votes, :limit => 15, :order => "DESC")
    end

    def recent(posts)
      posts.sort_by(:datetime, :order => "ALPHA DESC", :limit => 15)
    end

    def vote_post(post)
      voted = current_user.voted_for?(post) if logged_in?
      capture_haml do
        haml_tag(:form, :action => "/posts/#{post.id}", :method => "post", :class => "vote") do
          haml_tag(:button, "♥", :type => "submit", :class => voted ? "voted" : "")
        end
      end
    end
  end

  include Helpers
end
