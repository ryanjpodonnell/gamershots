module ScreenshotFilterer
  def _filter_screenshots
    methods = _build_method_chain

    methods.inject(Screenshot) { |obj, method| obj.send(*method) }
      .order("random()")
      .first
  end

  def _build_method_chain
    session.keys.map do |field|
      case field
      when "platforms", "publishers"
        _build_like_method(field)
      when "minimum_year"
        minimum_date = "01-01-#{session[field]}"
        _build_equality_method(">=", "original_release_date", minimum_date)
      when "maximum_year"
        maximum_date = "12-31-#{session[field]}"
        _build_equality_method("<=", "original_release_date", maximum_date)
      when "number_of_user_reviews"
        _build_equality_method(">=", field, "1")
      end
    end.compact
  end

  def _build_like_method(field)
    selected_values = session[field].map{ |value| "%\"#{value}\"%" }
    query = (["#{field} LIKE ?"] * selected_values.count).join(" OR ")
    [:where, query, *selected_values]
  end

  def _build_equality_method(operator, field, value)
    query = "#{field} #{operator} ?"
    [:where, query, value]
  end
end
