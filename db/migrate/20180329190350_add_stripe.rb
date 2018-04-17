# frozen_string_literal: true

class AddStripe < ActiveRecord::Migration
  def change
    add_column :users, :stripe_last4, :string
    add_column :users, :stripe_id, :string
  end
end

