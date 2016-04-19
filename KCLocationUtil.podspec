Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '8.0'
s.name = "KCLocationUtil"
s.summary = "This is a very useful location managing utility which handles basic location related tasks."
s.requires_arc = true

# 2
s.version = "1.2"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Kumar C" => "kumarchikkanna1@gmail.com" }

# For example,
# s.author = { "Joshua Greene" => "jrg.developer@gmail.com" }


# 5 - Replace this URL with your own Github page's URL (from the address bar)
s.homepage = "https://github.com/kumarc-123/KCLocationUtil"

# For example,
# s.homepage = "https://github.com/JRG-Developer/RWPickFlavor"


# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/kumarc-123/KCLocationUtil.git", :tag => "#{s.version}"}

# For example,
# s.source = { :git => "https://github.com/JRG-Developer/RWPickFlavor.git", :tag => "#{s.version}"}


# 7
# s.framework  = "SomeFramework"

s.frameworks = "CoreLocation", "MapKit"

#s.dependency 'Alamofire', '~> 2.0'
#s.dependency 'MBProgressHUD', '~> 0.9.0'

# 8
#s.source_files = "KCLocationUtil/**/*.{swift}"
s.source_files  = "KCLocationUtil/**/*.{h,m}"

# 9
#s.resources = "KCLocationUtil/**/*.{png,jpeg,jpg,storyboard,xib}"
end
