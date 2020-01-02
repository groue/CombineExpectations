Pod::Spec.new do |s|
  s.name = 'CombineExpectations'
  s.version = '0.4.0'
  s.summary = 'Utilities for tests that wait for Combine publishers'
  s.homepage = 'https://github.com/groue/CombineExpectations'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Gwendal Roué' => 'https://github.com/groue' }
  s.source = { :git => 'https://github.com/groue/CombineExpectations.git', :tag => s.version.to_s }

  s.swift_version = '5.1'
  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'
  s.osx.deployment_target = '10.15'

  s.subspec 'Sources' do |cs|
    cs.source_files = 'Sources/**/*.swift'
    cs.framework = 'XCTest'
  end

  s.test_spec 'Tests' do |ts|
    ts.source_files = 'Tests/CombineExpectationsTests/*.swift'
  end
end
