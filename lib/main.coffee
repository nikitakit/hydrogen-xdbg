# coffeelint: disable = missing_fat_arrows
# term = require 'term-launcher'
path = require 'path'
{CompositeDisposable, Disposable} = require 'atom'
StatusView = require './status-view'

module.exports = HydrogenLauncher =
    subscriptions: null
    hydrogenProvider: null

    statusBarView: null
    statusBarTile: null

    activeKernel: null

    activate: (state) ->
        @subscriptions = new CompositeDisposable

        @statusBarView = new StatusView()
        @statusBarView.setStatus null

        @subscriptions.add atom.workspace.observeActivePaneItem (item) =>
            if item and item is atom.workspace.getActiveTextEditor()
                @sendScopeToIdleKernel()

    deactivate: ->
        @subscriptions.dispose()
        @statusBarView.destroy()

    consumeStatusBar: (statusBar) ->
        @statusBarTile = statusBar.addLeftTile
            item: @statusBarView.element, priority: 101

    consumeHydrogen: (provider) ->
        console.log "Hydrogen consumed"
        @hydrogenProvider = provider

        @hydrogenProvider.onDidChangeKernel (kernel) =>
            @activateKernel kernel

        new Disposable =>
            @hydrogenProvider = null

    _filterKernel: (kernel) ->
        unless kernel?._kernel?.constructor?.name == "WSKernel"
            return null
        return kernel

    _setupComm: (kernel, comm) ->
        kernel._xdbgcomm = comm
        comm.onMsg = (msg) ->
            console.log "Got comm msg", msg
            kernel._xdbgscope = msg.content.data.scope
        comm.onClose = (msg) ->
            comm.dispose()

    activateKernel: (kernel) ->
        kernel = @_filterKernel kernel
        unless kernel?
            @statusBarView.setStatus null
            @activeKernel = null
            return

        unless kernel._xdbgcomm?
            session = kernel._kernel.session

            # This is used if we import xdbg partway through a session
            session.kernel.registerCommTarget 'xdbg', (comm, commMsg) =>
                unless commMsg.content.target_name is 'xdbg'
                    return
                @_setupComm kernel, comm

            comm = session.kernel.connectToComm('xdbg')
            @_setupComm kernel, comm

            kernel._xdbgscope = '?'
            kernel._xdbgfile = ''
            comm.open('')

            session.statusChanged.connect (status) =>
                unless status is "idle"
                    return

                unless kernel is @activeKernel
                    return

                console.log "Got status change to idle", kernel._xdbgfile
                if kernel._xdbgfile is not atom.workspace.getActiveTextEditor().getPath()
                    @sendScopeToIdleKernel()


        @activeKernel = kernel
        @statusBarView.setStatus kernel._xdbgscope
        @sendScopeToIdleKernel()

    sendScopeToIdleKernel: ->
        unless @activeKernel?
            return

        currentPath = atom.workspace.getActiveTextEditor().getPath()
        kernel = @activeKernel

        if kernel._xdbgfile == currentPath
            return

        session = kernel._kernel.session
        if session.status is not "idle"
            return

        if kernel._xdbgcomm.isDisposed
            return

        console.log "Requesting switch to scope", currentPath

        executeRequest =
            code: "%scope " + currentPath
        if session.kernel.execute?
            future = session.kernel.execute(executeRequest)
        else
            future = session.kernel.requestExecute(executeRequest)
        # future = kernel._xdbgcomm.send(
        #     path: currentPath
        # )
        future.onDone = =>
            if @activeKernel is kernel
                @statusBarView.setStatus kernel._xdbgscope
            kernel._xdbgfile = currentPath
