require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rcov/rcovtask'
#require 'meta_project'

PROJECT_NAME = 'Kitty'
PROJECT_AUTHOR = 'El Barto'

RUBYFORGE_PROJECT_NAME = 'kitty'
RUBYFORGE_USER = 'elbarto'

BIN_FILES = FileList['bin/*']
LIB_DIR = 'lib'
LIB_FILES = FileList["#{LIB_DIR}/**/*.rb"]
EXT_DIR = 'ext'
TEST_DIR = 'test'
TEST_FILES = FileList["#{TEST_DIR}/**/tc_*.rb"]
RDOC_HTML_DIR = 'rdoc'

REQUIRE_PATHS = [LIB_DIR, EXT_DIR]
$LOAD_PATH.concat(REQUIRE_PATHS)
require "#{PROJECT_NAME.downcase}"
PROJECT_VERSION = eval("#{PROJECT_NAME}::VERSION")

# CLEAN.include('*.x')

desc "Run all the tests"
task :default => [:test]

# rake test                           # run tests normally
# rake test TEST=just_one_file.rb     # run just one test file.
# rake test TESTOPTS='-v'             # run in verbose mode
Rake::TestTask.new do |t|
  t.libs << REQUIRE_PATHS
  t.test_files = TEST_FILES
  t.verbose = true
end

Rcov::RcovTask.new do |t|
 t.test_files = TEST_FILES
 #t.rcov_opts << "--test-unit-only"
end


Rake::RDocTask.new do |rd|
  # rd.main = 'README.rdoc'
  # rd.rdoc_files.include('README.rdoc', "#{LIB_DIR}/**/*.rb")
  rd.rdoc_files = LIB_FILES
  rd.rdoc_dir = RDOC_HTML_DIR
  rd.title = PROJECT_NAME
  rd.options << '--inline-source' << '--line-numbers' << '--tab-width=2'
end

desc 'Upload documentation to Rubyforge'
task :upload_docs => [:rdoc] do
  sh "find #{RDOC_HTML_DIR} -type d -exec chmod 775 {} \;"
  sh "find #{RDOC_HTML_DIR} -type f -exec chmod 664 {} \;"
  sh "scp -r #{RDOC_HTML_DIR}/* #{RUBYFORGE_USER}@rubyforge.org:/var/www/gforge-projects/#{RUBYFORGE_PROJECT_NAME}/",
    :verbose => true
end

Rake::PackageTask.new(RUBYFORGE_PROJECT_NAME, PROJECT_VERSION) do |p|
  p.need_zip = true
  p.need_tar_gz = true
  p.package_files.
    include('Rakefile'). # README INSTALL TODO CHANGELOG LICENSE
    include('setup.rb').
    include(BIN_FILES).
    include(LIB_FILES).
    include(TEST_FILES)
end

