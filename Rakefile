require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/contrib/sshpublisher'
require 'rake/contrib/rubyforgepublisher'
#require 'meta_project'

# CLEAN.include('*.x')
CLOBBER.include('coverage')

# rake test                           # run tests normally
# rake test TEST=just_one_file.rb     # run just one test file.
# rake test TESTOPTS='-v'             # run in verbose mode
Rake::TestTask.new do |t|
  #t.ruby_opts << '-rcoverage'
  t.libs << 'test'
  t.test_files = FileList['test/ts_kitty.rb']
  t.verbose = true
end

# rake rdoc           # generate the rdoc files
# rake clobber_rdoc   # delete all the rdoc files.
# rake rerdoc         # rebuild the rdoc files from scratch, even if they are not out of date.
Rake::RDocTask.new do |rd|
  # rd.main = 'README.rdoc'
  # rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
  rd.rdoc_files.include('lib/**/*.rb')
  rd.rdoc_dir = 'doc'
  # rd.title = 'Kitty'
  rd.options << '--inline-source' << ' --line-numbers' << ' --tab-width 2'
end

desc 'Upload current documentation to Rubyforge'
task :upload_docs => [:rdoc] do
  sh 'find doc -type d -exec chmod 775 {} \;'
  sh 'find doc -type f -exec chmod 664 {} \;'
  sh 'scp -r doc/* elbarto@rubyforge.org:/var/www/gforge-projects/kitty/'
end

desc 'Create distribution file'
Rake::PackageTask.new('kitty', '0.0.1') do |p| # Introduce parameter for
  p.need_tar = true
  p.package_files.
    include('Rakefile'). # README INSTALL TODO CHANGELOG LICENSE
    include('setup.rb').
    #include('bin/*.sh'). # FIXME no 'bin' dir
    include('lib/**/*.rb').
    include('test/**/*.rb')
end

desc "Show library's code statistics"
task :stats do
  $:.push('/usr/share/rails/railties/lib/')
  require 'code_statistics'
  CodeStatistics.new( ['Kitty', 'lib'], 
                      ['Units', 'test'] ).to_s
end
