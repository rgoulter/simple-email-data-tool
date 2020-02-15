require 'capybara/dsl'

require 'date'

module Page
  module EDRP
    EDRPC_PFX = "EDRPCalendar"

    APPLY_BTN_SELECTOR = ".EDRP__button--primary"
    INPUT_SELECTOR = ".EDRP__input"
    MONTH_SELECTOR = ".#{EDRPC_PFX}__month"  # .text = Dec 2018, Jan 2019, etc.
    NAV_SELECTOR = ".#{EDRPC_PFX}__nav"

    MONTH_FORMAT = "%b %Y" # e.g. Dec 2018, Jan 2019
    CELL_DATE_FORMAT = "%Y-%m-%d" # e.g. "2019-02-01" for 1st Feb 2019

    class << self
      include Capybara::DSL

      def months
        month_ths = all(MONTH_SELECTOR)
        month_ths.map { |th| Date.strptime(th.text, MONTH_FORMAT) }
      end

      def navs
        all(NAV_SELECTOR)
      end

      def navigate_month_earlier
        nav_earlier = navs[0]
        nav_earlier.click
      end

      def navigate_month_later
        nav_later = navs[1]
        nav_later.click
      end

      def seek_month(date)
        loop do
          month = months[0]
          break if date >= month
          navigate_month_earlier
        end
        loop do
          month = months[1]
          break if date <= month
          navigate_month_later
        end
      end

      def click_on_date(date)
        seek_month(date)
        yyyymmdd = date.strftime(CELL_DATE_FORMAT)
        cell= all(".#{EDRPC_PFX}__cell[title='#{yyyymmdd}']")[0]
        cell.click
      end

      def open
        find(INPUT_SELECTOR).click
      end

      def save
        find(APPLY_BTN_SELECTOR).click
      end

      def select_date_range(date1, date2)
        open
        click_on_date(date1)
        click_on_date(date2)
        save
      end
    end
  end
end
