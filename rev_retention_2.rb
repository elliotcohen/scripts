def revenue_and_user_count_by_time(uids, latest_date)
  revenue_by_time = Array.new(36).fill(0)
  user_potential_at_time = Array.new(36).fill(0)
  trxns = Qs1Transaction.joins(:bill).where("qs1_transactions.date IS NOT NULL AND qs1_transactions.date < ? AND bills.user_id IN (?)", latest_date, uids).includes(:bill)

  #build user hash - userid => min date
  puts "Building User Hash"
  user_h = {}
  trxns.each do |t|
    if user_h[t.bill.user_id].nil?
      user_h[t.bill.user_id] = t.date
    elsif user_h[t.bill.user_id] > t.date
      user_h[t.bill.user_id] = t.date
    end
  end

  #compute revenue
  puts "Computing Revenue"
  actual_transacted_users = {}
  trxns.each do |t|

    month = ((t.date - user_h[t.bill.user_id]) / 30).to_i
    revenue_by_time[month] += t.total.to_f unless t.total.nil?

    if actual_transacted_users[month].nil?
      actual_transacted_users[month] = [t.bill.user_id]
    else
      actual_transacted_users[month] << t.bill.user_id
    end
  end

  puts "Computing transacted users"
  transacted_user_counts = []
  actual_transacted_users.keys.sort.each do |month|
    transacted_user_counts << actual_transacted_users[month].uniq.length
  end

  #compute user time
  puts "compute user potential"
  user_h.each do |uid, start_date|
    lifetime_month_count = ((latest_date - start_date)/30).to_i
    (0..lifetime_month_count).each {|i| user_potential_at_time[i] += 1}
  end

  return revenue_by_time, user_potential_at_time, transacted_user_counts
end
rev_by_time, user_by_time, transacted_user_counts = revenue_and_user_count_by_time(uids, Date.new(2016,5,7))

​#trxns_by_user = Qs1Transaction.joins(:bill).where(bills: {user_id: uids}).group(bills: :user_id)

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
    revenue_by_time, user_potential_at_time, transacted_user_counts = revenue_and_user_count_by_time(uids, Date.new(2016,5,7))
    rev_row = [channel + " revenue"] + revenue_by_time
    user_row = [channel + " user potential"] + user_potential_at_time
    transacted_row = [channel + " actual user counts"] + transacted_user_counts
    csv_r << rev_row
    csv_r << user_row
  end
  CSV.open("/Users/elliotcohen/Downloads/revenue_retention_by_channel.csv", 'w') do |csv|
    csv_r.each do |r|
      csv << r
    end
  end
end

revenue_retention_by_channel(fname)
