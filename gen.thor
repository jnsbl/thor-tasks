require "securerandom"

class Gen < Thor
  desc "id", "Generate random 32-char hexadecimal identifier"
  def id
    puts SecureRandom.uuid.tr("-", "")
  end

  desc "uuid", "Generate Universally Unique Identifier v4 (random)"
  def uuid
    puts SecureRandom.uuid
  end
end
