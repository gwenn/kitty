require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
#require 'meta_project'

PROJECT_NAME = 'kitty'
PROJECT_VERSION = '0.1'
USER = 'elbarto'

# CLEAN.include('*.x')
CLOBBER.include('coverage')

desc "Run all the tests"
task :default => [:test]

# rake test                           # run tests normally
# rake test TEST=just_one_file.rb     # run just one test file.
# rake test TESTOPTS='-v'             # run in verbose mode
Rake::TestTask.new do |t|
  #t.ruby_opts << '-rcoverage'
  t.libs << 'test'
  t.test_files = FileList['ts_kitty.rb']
  t.verbose = true
end

Rake::RDocTask.new do |rd|
  # rd.main = 'README.rdoc'
  # rd.rdoc_files.include('README.rdoc', 'lib/**/*.rb')
  rd.rdoc_files.include('lib/**/*.rb')
  rd.rdoc_dir = 'rdoc'
  rd.title = PROJECT_NAME.capitalize
  rd.options << '--inline-source' << ' --line-numbers' << ' --tab-width 2'
end

desc 'Upload documentation to Rubyforge'
task :upload_docs => [:rdoc] do
  sh 'find rdoc -type d -exec chmod 775 {} \;'
  sh 'find rdoc -type f -exec chmod 664 {} \;'
  sh "scp -r rdoc/* #{USER}@rubyforge.org:/var/www/gforge-projects/#{PROJECT_NAME}/"
end

Rake::PackageTask.new(PROJECT_NAME, PROJECT_VERSION) do |p|
  p.need_zip = true
  p.need_tar_gz = true
  p.package_files.
    include('Rakefile'). # README INSTALL TODO CHANGELOG LICENSE
    include('setup.rb').
    #include('bin/*.sh'). # FIXME no 'bin' dir
    include('lib/**/*.rb').
    include('test/**/*.rb')
end

desc "Create Darcs distribution"
task :dist do
  sh "darcs dist -d #{PROJECT_NAME}-#{PROJECT_VERSION}"
end

desc "Show library's code statistics"
task :stats do
  $:.push('/usr/share/rails/railties/lib/')
  require 'code_statistics'
  CodeStatistics.new( [PROJECT_NAME.capitalize, 'lib'], 
                      ['Units', 'test'] ).to_s
end
