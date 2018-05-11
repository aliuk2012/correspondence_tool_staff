class SearchQueryDecorator < Draper::Decorator
  delegate_all

  def user_roles
    object.user.roles.join " "
  end

  def user_name
    object.user.full_name
  end

  def query_details
    object.query.reject{ |name, values| values.blank?}
  end
end
