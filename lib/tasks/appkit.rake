namespace :appkit do
  desc "Generate a VAPID key pair for web push and print a credentials.yml.enc snippet"
  task vapid_keys: :environment do
    key = WebPush.generate_key

    puts "Public key:  #{key.public_key}"
    puts "Private key: #{key.private_key}"
    puts
    puts "Paste into credentials.yml.enc (bin/rails credentials:edit):"
    puts <<~YAML
      web_push:
        vapid_public_key: #{key.public_key}
        vapid_private_key: #{key.private_key}
        subject: mailto:you@example.com
    YAML
  end
end
