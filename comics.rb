%w(sinatra models).each  { |lib| require lib}

helpers do
  
  include Rack::Utils
  
  alias_method :h, :escape_html

  def protected!
    response['WWW-Authenticate'] = %(Basic) and \
    throw(:halt, [401, "Not authorized\n"]) and \
    return unless authorized?
  end

  def authorized?
    comics = Comics.first
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [comics.login, comics.password]
  end
  
  def url_for url_fragment, mode=:full
    case mode
    when :path_only
      base = request.script_name
    when :full
      scheme = request.scheme
      if (scheme == 'http' && request.port == 80 || scheme == 'https' && request.port == 443)
        port = ""
      else
        port = ":#{request.port}"
      end
      base = "#{scheme}://#{request.host}#{port}#{request.script_name}"
    else
      raise TypeError, "Unknown url_for mode #{mode}"
    end
    "#{base}#{url_fragment}"
  end

end

['/admin/?', '/admin/dashboard'].each do |path|
  get path do
    protected!
    @comics = Comics.first
    haml :dashboard
  end
end

get '/admin/settings' do
  protected!
  @comics = Comics.first
  haml :settings
end

post '/admin/settings' do
  protected!
  Comics.first.update_attributes(params)
  redirect '/admin/settings'
end

get '/admin/add' do
  protected!
  @comics = Comics.first
  haml :add
end

post '/admin/add' do
  protected!
  strip = Strip.new
  strip.attributes = { :title => params[:title], :description => params[:description], 
                       :image => params[:image], :created_at => Time.now }
  strip.save!
  redirect '/admin/list'
end

get '/admin/list' do
  protected!
  @comics = Comics.first
  @strips = Strip.all
  haml :edit
end

get '/admin/edit/:id' do
  protected!
  @comics = Comics.first
  @strip = Strip.get(params[:id])
  haml :doedit
end

post '/admin/edit' do
  protected!
  strip = Strip.get(params[:id])
  strip.attributes = { :title => params[:title], :description => params[:description], :image => params[:image] }
  strip.save!
  redirect '/admin/list'
end

get '/admin/delete/:id' do
  protected!
  Strip.get(params[:id]).destroy
  redirect '/admin/list'
end

get '/list' do
  @comics = Comics.first
  @strips = Strip.all
  haml :list
end

get '/about' do
  @comics = Comics.first
  haml :about
end

get '/rss.xml' do
  @comics = Comics.first
  @strips = Strip.all :limit => 10
  haml(:rss, :layout => false)
end

['/', '/index', '/:id'].each do |path|
  get path do
    @comics = Comics.first
    @strip = Strip.get(params[:id]) || Strip.first
    haml :strip
  end
end