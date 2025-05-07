import Dagger
import Preferences

function set_distributed_package!(package_name::String)
    if package_name ∉ ("Distributed", "DistributedNext")
        throw(ArgumentError("Invalid distributed package: $(package_name)"))
    end
    Dagger.set_distributed_package!(package_name)
    Preferences.@set_preferences!("distributed-package" => package_name)
    @info("Preferences updated, restart your Julia session for this change to take effect")
end
