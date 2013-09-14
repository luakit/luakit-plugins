remote = {}

remote.manage = function(repos_to_watch, remote_policy, valid_plugins, plugins_dir, plugins_list)
    local repos_short = remote.shrink(repos_to_watch)

    local status = remote.get_status(repos_short, valid_plugins)

    for repo, data in pairs(status) do
        if data.state == "new" then
            remote.download(data.path)
        elseif remote_policy ~= nil and remote_policy == "automatic" then
            remote.update(repo)
        end
    end
end

remote.download = function(path)

end

remote.update = function(repo)

end

remote.get_status = function(repos_short, valid_plugins)
    local status = {}
    for repo_short, repo in pairs(repos_short) do
        local present = false
        for valid in pairs(valid_plugins) do
            if repo_short == valid then
                present = true
            end
        end

        status[repo_short] = {path = repo}

        if present == true then
            status[repo_short].state = "old"
        else
            status[repo_short].state = "new"
        end
    end

    return status
end

remote.shrink = function(repos_to_watch)
    local repos_short = {}
    for _, repo in pairs(repos_to_watch) do
        local repo_short = ""
        for c in repo:gmatch(".") do
            if c == "/" then
                repo_short = ""
            else
                repo_short = repo_short .. c
            end
        end

        if repo_short:find(".git") ~= nil then
            repo_short = repo_short:sub(0, -5)
        end
        
        repos_short[repo_short] = repo
    end

    return repos_short
end

return remote
