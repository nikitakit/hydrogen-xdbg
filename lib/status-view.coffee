module.exports =
class StatusView

    constructor: ->
        @element = document.createElement('div')
        @element.classList.add('xdbg')
        @element.classList.add('status')
        @element.innerText = '[xdbg loading]'


    setStatus: (status) ->
        if status?
            @element.innerText = 'xdbg: ' + status
        else
            @element.innerText = ''


    destroy: ->
        @element.innerHTML = ''
        @element.remove()
