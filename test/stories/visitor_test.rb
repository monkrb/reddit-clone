# encoding: UTF-8

require File.join(File.dirname(__FILE__), "../test_helper")
require File.join(File.dirname(__FILE__), "../stories_helper")

class VisitorTest < Test::Unit::TestCase
  setup do
    Ohm.flush
  end

  def login(username, password)
    visit "/login"

    fill_in "Your username", :with => username
    fill_in "Your password", :with => password

    click_button "Login"
  end

  story "As a visitor I want to create an account so that I can access restricted features." do
    scenario "A visitor submits good information" do
      visit "/"

      click_link "Sign up"

      fill_in "Choose a username", :with => "albert"
      fill_in "And a password", :with => "monkey"

      click_button "Sign up"

      assert_contain "Logged in as"
      assert_contain "albert"
    end

    scenario "A visitor submits an existing username" do
      User.spawn(:username => "albert")

      visit "/"

      click_link "Sign up"

      fill_in "Choose a username", :with => "albert"
      fill_in "And a password", :with => "monkey"

      click_button "Sign up"

      assert_contain "Someone else owns the username “albert”."
    end

    scenario "A visitor forgot that she's already registered" do
      User.spawn(:username => "maria")

      visit "/"

      click_link "Sign up"

      fill_in "Choose a username", :with => "maria"
      fill_in "And a password", :with => "monkey"

      click_button "Sign up"

      assert_contain "Someone else owns the username “maria”."
      click_link "Maybe it's you?"

      fill_in "Your password", :with => "monkey"
      click_button "Login"
      assert_contain "Logged in as"
      assert_contain "maria"
    end

    scenario "A visitor tries to sign up without a password" do
      visit "/"

      click_link "Sign up"

      fill_in "Choose a username", :with => "albert"
      fill_in "And a password", :with => ""

      click_button "Sign up"

      assert_contain "We won't be able to authenticate you if you don't provide a password."
    end
  end

  story "As a user I want to log in to my account so I can resume my activities in the website." do
    setup do
      @user = User.spawn(:username => "albert", :password => "monkey")
    end

    scenario "A visitor logs in successfully" do
      visit "/"

      click_link "Login"

      fill_in "Your username", :with => "albert"
      fill_in "Your password", :with => "monkey"

      click_button "Login"

      assert_contain "Logged in as"
      assert_contain "albert"
      assert_not_contain "Login"

      click_link "Logout"
      assert_not_contain "Hello albert"
    end

    scenario "A visitor supplies the wrong credentials" do
      visit "/"

      click_link "Login"

      fill_in "Your username", :with => "simon"
      fill_in "Your password", :with => "wronglet"

      click_button "Login"

      assert_contain "We are sorry: the information supplied is not valid."
    end
  end

  story "As a user I want to post a post so that I can publicize it." do
    setup do
      @user = User.spawn(:username => "albert")
    end

    scenario "A user supplies good values for a post" do
      login(@user.username, "monkey")

      click_link "Submit a link"

      fill_in "URL", :with => "Monk, the glue framework"
      fill_in "Title", :with => "http://monkrb.com"

      click_button "Submit link"

      assert_contain "Your link has been added"
    end

    scenario "A user does not supply enough values for a post" do
      login(@user.username, "monkey")

      click_link "Submit a link"

      click_button "Submit link"

      assert_contain "The field “URL” is mandatory"
      assert_contain "The field “Title” is mandatory"

      fill_in "URL", :with => "LAwebdev Meetup"
      click_button "Submit link"

      assert_contain "The field “Title” is mandatory"

      fill_in "Title", :with => "http://lawebdev.com"
      click_button "Submit link"

      assert_contain "Your link has been added"
    end

    scenario "A visitor creates a post and provides valid login information" do
      visit "/"

      click_link "Submit a link"

      fill_in "URL", :with => "Fresh news"
      fill_in "Title", :with => "http://reddit.com"

      fill_in "Your username", :with => "albert"
      fill_in "Your password", :with => "monkey"

      click_button "Submit link"

      assert_contain "Your link has been added"
    end

    scenario "A visitor creates a post and provides invalid login information" do
      visit "/"

      click_link "Submit a link"

      fill_in "URL", :with => "Fresh news"
      fill_in "Title", :with => "http://reddit.com"

      fill_in "Your username", :with => "foo"
      fill_in "Your password", :with => "monkey"

      click_button "Submit link"

      assert_not_contain "Your link has been added"
      assert_contain "We couldn't find a user with the information provided."
    end

    scenario "A visitor creates an account and a post at the same time" do
      visit "/"

      click_link "Submit a link"

      fill_in "URL", :with => "Fresh news"
      fill_in "Title", :with => "http://reddit.com"

      choose "I'm new here"

      fill_in "Your username", :with => "new_guy"
      fill_in "Your password", :with => "monkey"

      click_button "Submit link"

      assert_contain "Your link has been added"
      assert_contain "Logged in as"
      assert_contain "new_guy"
    end
  end

  story "As a user I want my name to appear on the links I create so I can be popular." do
    setup do
      @user = User.spawn :username => "matilda"
      @post = Post.spawn :name => "Monk News", :author => @user.id, :datetime => Time.now.to_s
    end

    scenario "A user visits a post" do
      login(@user.username, "monkey")

      visit "/"
      click_link "Monk News"

      assert_contain "matilda"
    end
  end

  story "As a visitor I want to see the link's date so that I know when the link was added." do
    setup do
      @user = User.spawn
      @post = Post.spawn \
        :name => "Ruby Tuesday",
        :location => "http://ruby-lang.org",
        :datetime => "10/07/2009 00:00"
    end

    scenario "A user visits a post" do
      login(@user.username, "monkey")

      visit "/posts/#{@post.id}"

      assert_contain "10/07/2009"
    end
  end

  story "As a visitor I want to see the post's location linked so I can visit the destination." do
    setup do
      @user = User.spawn
      @post = Post.spawn \
        :name => "Ruby Tuesday",
        :location => "http://ruby-lang.org"
    end

    scenario "A user visits a post he created" do
      login(@user.username, "monkey")

      visit "/posts/#{@post.id}"

      assert_have_selector "h2", :content => "Ruby Tuesday"
      assert_have_xpath "//a[@href='http://ruby-lang.org']"
    end
  end

  story "As a visitor I want to see today and yesterday's links so that I can find something to do." do
    setup do
      @today = Post.spawn :name => "Ruby Tuesday", :datetime => "07/16/2009"
      @tomorrow = Post.spawn :name => "Ruby Hoedown", :datetime => "07/15/2009"
      @the_day_before_yesterday = Post.spawn :name => "Past Ruby", :datetime => "07/14/2009"
    end

    scenario "A user visits a post he created" do
      visit "/"

      assert_contain "Today"
      assert_contain "Ruby Tuesday"

      assert_contain "Yesterday"
      assert_contain "Ruby Hoedown"
    end

    scenario "A user navigates back in time" do
      visit "/"

      click_link "Previous"

      assert_contain "Past Ruby"
    end
  end

  story "As a visitor I want to see what has been just posted so that I know what's fresh." do
    setup do
      Post.spawn(:name => "JRuby 2.0 Released", :location => "http://some.blog.com")
      Post.spawn(:name => "JRuby 2.1 Released (bugfix)", :location => "http://some.other.blog.com")
    end

    scenario "A user visits the homepage and sees recently posted stuff" do
      visit "/"

      assert_have_selector ".just_added a", :content => "JRuby 2.0 Released"
      assert_have_selector ".just_added a", :content => "JRuby 2.1 Released (bugfix)"
    end
  end

  story "As a visitor I want to see links for any given date so I can make plans." do
    setup do
      @date = "06/28/2009"
      @post = Post.spawn :datetime => @date
    end

    scenario "A user visits a given date" do
      visit "?date=2009-06-28"

      assert_contain @post.name
    end
  end

  story "As a visitor I want to see a user's profile so that I can see their identity." do
    setup do
      @user = User.spawn :username => "albert"
    end

    scenario "A visitor checks a user profile" do
      visit "/users/albert"

      assert_contain "albert"
    end
  end

  story "As a user I want to vote for a post so that I can increase its popularity." do
    setup do
      @user = User.spawn(:username => "albert")
      @post = Post.spawn
    end

    scenario "A user visits a post and votes" do
      login(@user.username, "monkey")

      visit "/posts/#{@post.id}"

      report "Vote for the post" do
        click_button "♥"
      end

      assert_have_selector "span.votes", :content => "1"
    end

    scenario "A user cannot vote more than once" do
      login(@user.username, "monkey")

      visit "/posts/#{@post.id}"

      report "Vote for the post" do
        click_button "♥"
      end

      assert_have_selector "span.votes", :content => "1"
    end
  end

  story "As a visitor I want to see how many votes a post has so I can know whether it's popular or not." do
    setup do
      @post = Post.spawn
      @post.incr(:votes)
      @post.incr(:votes)
      @post.incr(:votes)
    end

    scenario "A user visits a post that has received some votes" do
      visit "/posts/#{@post.id}"

      assert_have_selector "span.votes", :content => "3"
    end
  end

  story "As a user I want to remove my vote for a post so that I can reflect my change of mind." do
    setup do
      @user = User.spawn(:username => "albert")
      @post = Post.spawn
    end

    scenario "A user visits a post and removes his vote" do
      login(@user.username, "monkey")

      visit "/posts/#{@post.id}"

      report "Vote for the post" do
        click_button "♥"
      end

      assert_have_xpath("//button[@class='voted']")
      assert_have_selector "span.votes", :content => "1"

      report "Vote for the post" do
        click_button "♥"
      end

      assert_have_xpath("//button[@class='']")
      assert_have_selector "span.votes", :content => "0"
    end
  end

  story "As a visitor I want to browse the timeline so that I can move forward and backwards in time." do
    scenario "A user browses the timeline" do
      visit "/"

      click_link "Previous"
      assert_contain "Yesterday"

      click_link "Next"
      assert_contain "Today"
    end
  end

  story "As a visitor I want to see links created or voted by a user so that I can know what they are up to." do
    setup do
      @user = User.spawn :username => "albert"
      @link1 = Post.spawn :name => "Own Link", :author => @user.id
      @link2 = Post.spawn :name => "Voted Link 1"
      @link3 = Post.spawn :name => "Voted Link 2"
      @link4 = Post.spawn :name => "Another Link"
      @user.vote_for(@link2)
      @user.vote_for(@link3)
    end

    scenario "A visitor checks a user profile" do
      visit "/users/albert"

      assert_contain "Own Link"
      assert_contain "Voted Link 1"
      assert_contain "Voted Link 2"
      assert_not_contain "Another Link"
    end
  end
end
