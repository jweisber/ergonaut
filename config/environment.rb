# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Ergonaut::Application.initialize!

# Monkey patch for MySQL 5.7
require File.expand_path('../../lib/patches/abstract_mysql_adapter', __FILE__)