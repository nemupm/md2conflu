module Md2conflu
  module Util
    module Common
      def to_classname(str)
        str.sub(/^#{@plugin_base}/){""}.sub(/\.rb$/){""}.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      end
    end
  end
end
