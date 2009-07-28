class Main
  get '/styles/:stylesheet.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :"styles/sass/#{params[:stylesheet]}"
  end
end
