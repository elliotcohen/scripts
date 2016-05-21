#Revenue retention by cohort


#We define cohort by 30 day windows around first transaction
def revenue_by_cohort(uids, latest_date)
  trxns_by_user = Qs1Transaction.joins(:bill).where("qs1_transactions.date IS NOT NULL AND qs1_transactions.date < ? AND bills.user_id IN (?)", latest_date, uids).order("qs1_transactions.date").includes(:bill).group_by{|t| t.bill.user_id}

  puts "Building User Cohorts"
  user_cohorts = {}
  trxns_by_user.each do |uid, trxns|
    #assuming that the first transaction is the earliest since the trxns were sorted by date in query
    month = ((latest_date - trxns[0].date) / 30).to_i
    if user_cohorts[month].nil?
      user_cohorts[month] = [uid]
    else
      user_cohorts[month] << uid
    end
  end

  puts "Building cohort revenue hash"
  cohort_rev = {}
  user_cohorts.each do |month, uids|
    rev_by_month = Array.new(month).fill(0)
    uids.each do |uid|
      start_date = trxns_by_user[uid][0].date
      trxns_by_user[uid].each do |t|
        rev_month = ((t.date - start_date)/30).to_i
        rev_by_month[rev_month] += t.total.to_f
      end
    end

    cohort_rev[month] = rev_by_month
  end

  return cohort_rev
end



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
  channel_h.each do |channel, uids|
    puts "Starting Channel: #{channel}"
    cohort_rev = revenue_by_cohort(uids, Date.new(2016,5,7))

    CSV.open("/Users/elliotcohen/Downloads/revenue_cohort_retention_#{channel}.csv", 'w') do |csv|
      csv << ['Cohort Lifetime']
      cohort_rev.each do |month, rev_by_month|
        csv << [month] + rev_by_month
      end
    end
  end
end

#revenue_retention_by_channel("data/by_channel.csv")
