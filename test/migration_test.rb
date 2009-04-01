require 'test_helper'

class MigrationTest < ActiveSupport::TestCase
  
  def open_file(name)
    File.open(File.join(RAILS_ROOT, "app", "models", name))
  end
  
  context "migrations" do
    should "run columnize after migrations" do
      WhatColumn::Columnizer.expects(:add_column_details_to_models).at_least_once
      ActiveRecord::Migrator.migrate("#{RAILS_ROOT}/db/migrate")
    end
  end
  
end