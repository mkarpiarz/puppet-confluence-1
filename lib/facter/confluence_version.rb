# Still, not an ideal solution (it needs a Confluence process
# running), but at least is not introducing potential conflicts
# with resources outside the module.

Facter.add(:confluence_version) do
  setcode do
    # Get a list of processes and look for the confluence one.
    conf_proc = %x{ps ax}.split("\n").detect{ |x| x.include?('atlassian-confluence') }
    if conf_proc.nil?
      # Make sure the fact is set to a something even if the list is nil.
      "unknown"
    else
      # Get version from a running process.
      conf_proc.split(/[- \/]/).detect{ |x| x =~ /^(\d+\.){1,2}\d*$/ }
    end
  end
end
