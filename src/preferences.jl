import Dagger
import Preferences

function set_distributed_package!(package_name::String)
    if package_name ∉ ("Distributed", "DistributedNext")
        throw(ArgumentError("Invalid distributed package: $(package_name)"))
    end
    Preferences.set_preferences!("Dagger", "distributed-package" => package_name;
                                 force = true)
    Preferences.set_preferences!("MemPool", "distributed-package" => package_name;
                                 force = true)
    Preferences.set_preferences!("TimespanLogging", "distributed-package" => package_name;
                                 force = true)
    Preferences.set_preferences!("FrameworkDemo", "distributed-package" => package_name;
                                 force = true)
    @info("Preferences updated; restart your Julia session to take effect!")
end
