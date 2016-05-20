def revenue(uids, start_date, end_date)
  return Qs1Transaction.join(:bill).where("qs1_transactions.date >= ? AND qs1_transactions.date < ? AND bills.user_id IN (?)", start_date, end_date, uids).sum(:total)
end


#For a group of users return their revenue in 30, 60, 90, etc day increments

def revenue_and_user_count_by_time(uids)
  revenue_by_time = Array.new(36).fill(0)
  user_potential_at_time = Array.new(36).fill(0)
  uids.each do |uid|
    trxns = Qs1Transaction.joins(:bill).where("bills.user_id = ?", uid)
    if trxns.count > 0
      start_date = trxns.pluck(:date).min
      end_date = trxns.pluck(:date).max
      trxns.each do |t|
        month = ((t.date - start_date) / 30).to_i
        revenue_by_time[month] += t.total.to_f
      end

      lifetime_month_count = ((end_date - start_date)/30).to_i
      (0..lifetime_month_count).each {|i| user_potential_at_time[i] += 1}
    end
  end

  return revenue_by_time, user_potential_at_time
end

#read all UIDs in and iterate over channels
def revenue_retention_by_channel(fname)
  uids_by_channel = CSV.read(fname)
  uids_by_channel = uids_by_channel[1..uids_by_channel.length]
  channel_h = {}
  uids_by_channel.each do |r|
    if channel_h[r[0]].nil?
      channel_h[r[0]] = [r[1]]
    else
      channel_h[r[0]] << r[1]
    end
  end

  #initialize csv with header
  csv_r = [[nil] + (0..35).to_a]

  channel_h.each do |channel, uids|
    puts "Starting Channel: #{channel}"

    revenue_by_time, user_potential_at_time = revenue_and_user_count_by_time(uids)

    rev_row = [channel + " revenue"] + revenue_by_time
    user_row = [channel + " user"] + user_potential_at_time

    csv_r << rev_row
    csv_r << user_row
  end

  CSV.open("/Users/elliotcohen/Downloads/revenue_retention_by_channel.csv", 'w') do |csv|
    csv_r.each do |r|
      csv << r
    end
  end
end
