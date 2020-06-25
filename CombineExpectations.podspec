Pod::Spec.new do |s|
  s.name     = 'CombineExpectations'
  s.version  = '0.5.0'
  
  s.license  = { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A set of extensions for SQLite, GRDB.swift, and Combine'
  s.homepage = 'https://github.com/groue/CombineExpectations'
  s.author   = { 'Gwendal Roué' => 'gr@pierlis.com' }
  s.source   = { :git => 'https://github.com/groue/CombineExpectations.git', :tag => "v#{s.version}" }
  s.module_name = 'GRDBCombine'
  
  s.swift_versions = ['5.2']
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '13.0'
  
  s.frameworks = ['Combine', 'XCTest']
  s.source_files = 'Sources/CombineExpectations/**/*.swift'
end
