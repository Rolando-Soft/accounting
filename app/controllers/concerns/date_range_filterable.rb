# Shared "View Filter" dropdown (This month/Last month/.../All dates) used
# by both the register and the account ledger report, so the two stay in
# sync rather than drifting into subtly different date math.
module DateRangeFilterable
  extend ActiveSupport::Concern

  VIEW_FILTERS = %w[this_month last_month last_3_months this_year last_year all_dates].freeze

  private

  def normalize_view_filter(value)
    VIEW_FILTERS.include?(value) ? value : "this_month"
  end

  # [from, to] for the filter, or [nil, nil] for "all_dates" (unbounded).
  def view_filter_range(filter)
    today = Date.current
    case filter
    when "last_month"
      [today.prev_month.beginning_of_month, today.prev_month.end_of_month]
    when "last_3_months"
      [3.months.ago.to_date, today]
    when "this_year"
      [today.beginning_of_year, today.end_of_year]
    when "last_year"
      [today.prev_year.beginning_of_year, today.prev_year.end_of_year]
    when "all_dates"
      [nil, nil]
    else # "this_month"
      [today.beginning_of_month, today.end_of_month]
    end
  end

  def within_date_range?(date, filter)
    from, to = view_filter_range(filter)
    from.nil? || date.between?(from, to)
  end
end
