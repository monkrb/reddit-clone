DAYS = %w{Sun Mon Tue Wed Thu Fri Sat}
DATE_FORMAT = "%m/%d/%Y"

def date(n = 0)
  format_date(Time.now + (86400 * n))
end

def format_date(date)
  date.strftime(DATE_FORMAT)
end
