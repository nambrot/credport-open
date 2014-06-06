class PostsController < ApplicationController
  before_filter :prepare
  before_filter :authenticate_user!, :only => [:new, :create]
  caches_action :show, :cache_path => :show_cache_path.to_proc, :expires_in => 4.hours
  # caches_action :index, :cache_path => :index_cache_path.to_proc
  def index_cache_path
    return "blog-index-#{current_user ? current_user.id : 0}-#{I18n.locale}"
  end
  def show_cache_path
    @post = Post.find(params[:id].split('-').first)
    return "blog-#{@post.cache_key}-#{current_user ? current_user.id : 0}-#{I18n.locale}"
  end
  def index
    @posts = Post.order("created_at DESC").all

    set_meta_tags({
      :title => "Credport Blog",
      :description => "Credport's Blog with thoughts on Collaborative Consumption and Startups in general",
      :keywords => ['collaborative consumption', 'sharing economy', 'blog'],
      :canonical => 'http://www.credport.org/blog',
      :open_graph => {
        :title => "Credport Blog",
        :description => "Credport's Blog with thoughts on Collaborative Consumption and Startups in general",
        :url => 'http://www.credport.org/blog',
        :type => 'blog',
        :image => ActionController::Base.helpers.asset_path("credportsquare.png"),
        :site_name => 'Credport'
      }
      })
    
  end

  def show
    @post = Post.find(params[:id].split('-').first)
    set_meta_tags({
      :title => "Credport - #{@post.title}",
      :description => @post.body,
      :keywords => ['collaborative consumption', 'sharing economy', 'blog'],
      :canonical => post_url(@post),
      :open_graph => {
        :title => @post.title,
        :description => ActionController::Base.helpers.truncate(ActionController::Base.helpers.strip_tags(@post.body).gsub(/\s+/, ' '), :length => 200),
        :url => post_url(@post),
        :type => 'article',
        :image => ActionController::Base.helpers.asset_path("credportsquare.png"),
        :site_name => 'Credport'
      }
      })
  end

  def prepare
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
        :autolink => true, :space_after_headers => true, :lax_spacing => true)
  end

  def new
    raise ActionController::RoutingError.new('Not Found') unless Rails.configuration.blog_admins.include? current_user.id.to_s
    @post = Post.new
  end

  def edit
    raise ActionController::RoutingError.new('Not Found') unless Rails.configuration.blog_admins.include? current_user.id.to_s
    @post = Post.find(params[:id].split('-').first)
  end

  def update
    raise ActionController::RoutingError.new('Not Found') unless Rails.configuration.blog_admins.include? current_user.id.to_s
    @post = Post.find(params[:id].split('-').first)
    @post.update_attributes params[:post]
    redirect_to post_path(@post)
  end

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "foo" && password == "bar"
    end
  end
  def create
    raise ActionController::RoutingError.new('Not Found') unless Rails.configuration.blog_admins.include? current_user.id.to_s
    @post = current_user.posts.build(params[:post])
    if @post.save
      redirect_to post_path(@post)
    else
      ap @post.errors
      redirect_to new_post_path
    end
  end

end
