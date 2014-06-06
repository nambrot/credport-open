class PagesController < HighVoltage::PagesController
  # caches_action :show, :cache_path => :show_cache_path.to_proc

  def show_cache_path
    return "page-#{params[:id]}-#{current_user ? current_user.id : 0}"
  end
end