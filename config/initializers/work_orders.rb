unless Rails.env.test?
  WorkOrders.configure do |config|
    config.folder = File.join('config', 'work_orders')
    config.load!
  end
end
