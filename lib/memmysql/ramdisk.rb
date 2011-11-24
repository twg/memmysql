class MemMySQL::Ramdisk
  def initialize(options)
    @options = options
  end
  
  def mount_path
    '/Volumes'
  end
  
  def path
    @path ||= File.expand_path(@options[:name], self.mount_path)
  end
  
  def create!
    blocks = @options[:size] * 2048
    
    if (system(%Q[diskutil erasevolume HFS+ "#{@options[:name]}" `hdiutil attach -nomount ram://#{blocks}`]))
    else
      # Ruh oh
    end
  end
  
  def destroy!
    # ...
  end
end
