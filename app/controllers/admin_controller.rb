class AdminController < ApplicationController
  before_filter :authenticate_admin!

  def reset_cache
    render :text => Rails.cache.clear
  end

  def stats
    @return = {
      :user_count => User.count,
      :identities_count => Identity.count,
      :connections_count => Connection.count,
      :last_five_users => User.limit(25).order("created_at DESC").map{|user| {:id => user.to_param, :url => user_url(user), :name => user.name}},
      :tamyca => {
        :users_with_tamyca => Identity.where(:context_id => IdentityContext.find_by_name('tamyca')).where('user_id IS NOT NULL').count,
        :reviews_from_tamyca => Connection.where(:context_id => ConnectionContext.find_by_name('tamyca-review')).count,
        :last_five_users_with_tamyca => User.limit(5).order("users.created_at DESC").includes(:identities).where(:identities => {:context_id => IdentityContext.find_by_name('tamyca')}).map{|user| {:id => user.to_param, :url => user_url(user), :name => user.name}}
      }
    }
    render :json => @return
  end

end
