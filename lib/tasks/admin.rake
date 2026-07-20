# frozen_string_literal: true

namespace :admin do
  desc 'Grant admin access to a user. Use EMAIL=user@example.com'
  task grant: :environment do
    email = ENV['EMAIL'].presence or abort 'Specify a user with EMAIL=user@example.com'
    user = User.find_by(email_address: email) or abort "No user found with email '#{email}'"

    if user.admin?
      puts "#{email} is already an admin."
    else
      user.update!(admin: true)
      puts "Granted admin access to #{email}."
    end
  end

  desc 'Revoke admin access from a user. Use EMAIL=user@example.com'
  task revoke: :environment do
    email = ENV['EMAIL'].presence or abort 'Specify a user with EMAIL=user@example.com'
    user = User.find_by(email_address: email) or abort "No user found with email '#{email}'"

    if user.admin?
      user.update!(admin: false)
      puts "Revoked admin access from #{email}."
    else
      puts "#{email} is not an admin."
    end
  end
end
