# Shared "View Filter" dropdown (This month/Last month/.../All dates) used
# by the register and the Journal Transactions list. Account Ledger,
# Project Ledger, Income Statement, Cash Flow Statement, and Project
# Profitability instead use ReportsController's own shared date-range
# picker (see #resolve_date_range) — a different, richer control with
# monthly columns and a Custom range, not a drop-in replacement for this.
module DateRangeFilterable
  extend ActiveSupport::Concern

  VIEW_FILTERS = %w[this_month last_month last_3_months this_year last_year all_dates].freeze

  private

  def normalize_view_filter(value)
    VIEW_FILTERS.include?(value) ? value : "this_month"
  end

  # [from, to] for the filter, or [nil, nil] for "all_dates" (unbounded).
  # Every relative option ("this month", "last 3 months", ...) is computed
  # relative to `through` instead of always today, so a report can let the
  # user step back to an arbitrary month rather than being stuck with
  # whatever "this month" means right now.
  def view_filter_range(filter, through: Date.current)
    case filter
    when "last_month"
      [ through.prev_month.beginning_of_month, through.prev_month.end_of_month ]
    when "last_3_months"
      [ (through - 3.months).to_date, through ]
    when "this_year"
      [ through.beginning_of_year, through.end_of_year ]
    when "last_year"
      [ through.prev_year.beginning_of_year, through.prev_year.end_of_year ]
    when "all_dates"
      [ nil, nil ]
    else # "this_month"
      [ through.beginning_of_month, through.end_of_month ]
    end
  end

  def within_date_range?(date, filter, through: Date.current)
    from, to = view_filter_range(filter, through: through)
    from.nil? || date.between?(from, to)
  end
end
