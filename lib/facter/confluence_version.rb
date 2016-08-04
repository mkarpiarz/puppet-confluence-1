# Still, not an ideal solution (it needs a Confluence process
# running), but at least is not introducing potential conflicts
# with resources outside the module.

Facter.add(:confluence_version) do
  setcode do
    # Get me all the processes and split into a bunch of tokens
    procs = %x{ps ax}.split("\n")
    # Select the confluence one, split the resulting string and extract version number
    procs.detect{ |x| x.include?('atlassian-confluence') }.split(/[- \/]/).detect{ |x| x =~ /^(\d+\.){1,2}\d*$/ }
  end
end
