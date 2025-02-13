require 'base64'

class PasswordCrypt
  ALGORITHMS = {'SHA512' => '$6$', 'SHA256' => '$5$', 'Base64' => '', 'Base64-Windows' => ''}
  # Matches ENCRYPT_METHOD in /etc/login.defs on EL6+
  # When changing this, be sure to add a migration for operatingsystems'
  # default value
  DEFAULT_HASH_ALGORHITHM = 'SHA512'

  if Foreman::Fips.md5_available?
    ALGORITHMS['MD5'] = '$1$'
  end

  def self.generate_linux_salt
    # Linux crypt accepts maximum 16 [a-zA-Z0-9./] characters
    SecureRandom.alphanumeric(16)
  end

  def self.passw_crypt(passwd, hash_alg = nil)
    hash_alg ||= DEFAULT_HASH_ALGORHITHM
    raise Foreman::Exception.new(N_("Unsupported password hash function '%s'"), hash_alg) unless ALGORITHMS.has_key?(hash_alg)

    case hash_alg
    when 'Base64'
      result = Base64.strict_encode64(passwd)
    when 'Base64-Windows'
      result = Base64.strict_encode64("#{passwd}AdministratorPassword".encode('utf-16le'))
    else
      result = passwd.crypt("#{ALGORITHMS[hash_alg]}#{generate_linux_salt}")
    end

    result.force_encoding(Encoding::UTF_8) if result.encoding != Encoding::UTF_8
    result
  end

  def self.grub2_passw_crypt(passw)
    passw_crypt(passw, 'SHA512')
  end

  def self.crypt_gnu_compatible?
    @crypt_gnu_compatible ||= passw_crypt("test_this").match('^\$\d+\$.+\$.+')
  end
end
