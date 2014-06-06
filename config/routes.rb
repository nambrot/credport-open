Credport::Application.routes.draw do
  use_doorkeeper do
    skip_controllers :applications
  end
  scope 'admin' do
    resources :applications, :controller => 'oauth_applications' do
      resources :identity_contexts
      resources :entity_contexts
      resources :connection_contexts
    end
  end
  match 'redirect_back' => 'oauth_applications#redirect_back_from_signup'

  mount DjMon::Engine => 'dj_mon'
  match '/auth/:provider/callback' => 'authcallbacks#create'

  # current_user routes
  get 'me' => 'users#me'
  get 'me/recommendations_to_approve' => 'reviews#me_to_approve'

  # user routes
  resources :u , :as => :users, :controller => "users" do
    post 'emails' => 'attributes#add_email_to_verify'
    post 'phones' => 'attributes#add_phone_to_verify'
    post 'websites' => 'attributes#add_website_to_verify' 
    post 'websites/:id/check' => 'attributes#check_website'
    post 'name' => 'attributes#change_name'
    post 'tagline' => 'attributes#change_tagline'
    post 'profilepictures' => 'attributes#add_profile_picture'
    post 'backgroundpicture' => 'attributes#add_background_picture'
    post 'remove_profile_picture' => "attributes#remove_profile_picture"
    
    # credport recommendations
    post 'reviews' => 'reviews#create'
    post 'reviews/request_by_email' => 'reviews#request_by_email'
    put 'reviews/:id/approve' => 'reviews#approve'
    delete 'reviews/:id' => 'reviews#destroy'
    get 'review' => 'reviews#show'
    put 'review' => 'reviews#update'
    get ':mode' => 'users#show'
  end

  post 'educationattribute/:id/:visibility' => 'attributes#set_educationattribute_visibility'
  post 'workattribute/:id/:visibility' => 'attributes#set_workattribute_visibility'
  post 'forms/profilepicture' => 'attributes#profilepicture_form'
  post 'forms/backgroundpicture' => 'attributes#backgroundpicture_form'
  get 'verify/email/:code' => 'attributes#verify_email'
  get 'verify/phone/:code' => 'attributes#verify_phone'
  post 'resend/email' => 'attributes#resend_email_code'
  post 'resend/phone' => 'attributes#resend_phone_code'
  
# utility
  get 'utility/country' => 'utility#country'
  get 'utility/verifieds' => 'utility#verifieds'
  get 'utility/csrf' => 'utility#csrf', :format => :js
  post 'utility/setLocale' => 'utility#setLocale'

# admin
  scope "/admin" do
    get 'reset_cache' => 'admin#reset_cache'
    get 'stats' => 'admin#stats'
  end

# authentication
  resources :sessions
  get "login" => "sessions#new", :as => 'login'
  get "logout" => "sessions#destroy", :as => "logout" 
  get 'signup' => "users#new", :as => "signup"
  match '/auth/:provider/callback' => 'authcallbacks#create'
  match '/auth/failure' => 'authcallbacks#fail'

# other pages
  root :to => 'pages#show', :id => 'publiclanding'
  match "/pages/*id" => 'pages#show', :as => :page, :format => false
  resources :blog, :as => :posts, :controller => 'posts'
  get "/marketplaces" => 'pages#show', :id => 'marketplaces'
  get "/usecredport" => 'pages#show', :id => 'usecredport'
  get "/howitworks" => 'pages#show', :id => 'howitworks'
  get "/tos" => 'pages#show', :id => 'tos'
  get "/privacy" => 'pages#show', :id => 'privacy'
  get "/about" => 'pages#show', :id => 'about'
  get "/webcred" => "pages#show", :id => 'webcred'
  get "/faq" => "pages#show", :id => 'faq'
  get '/docs/api' => 'pages#api', :id => 'api'
  get '/docs/ux' => 'pages#ux' , :id => 'ux'
  get 'impressum' => 'pages#show', :id => 'impressum'

  get '/nam' => 'users#show', :id => '2a681'
  get '/connor' => 'users#show', :id => '3a681'
  get '/samir' => 'users#show', :id => '7a681'
  
  namespace :api, :defaults => {:format => :json} do
    namespace :v1 do
      get 'me' => 'api#me'
      resources :reviews
      resources :users do
        get 'education' => 'users#education'
        get 'work' => 'users#work'
        get 'verifications' => 'users#verifications'
        get 'commoninterests' => 'users#commoninterests'
        get 'commonconnections' => 'users#commonconnections'
        get 'stats' => 'users#stats'
        resources :identities
        resources :reviews
      end
    end
  end
end
