module Monus::BuiltInMetric::EmThreadpool
  def activate
    @interval = Monus.options.dig(:em_threadpool_metric_options, :interval) || 1

    threadpool, threadqueue = nil, nil

    Monus.engine.every @interval do
      threadpool ||= EM.send(:instance_variable_get, :@threadpool)
      threadqueue ||= EM.send(:instance_variable_get, :@threadqueue)

      if threadpool and threadqueue
        total = threadpool.size
        alive = threadpool.count(&:alive?)
        broken = total - alive

        free = threadqueue.num_waiting
        busy = alive - free
        load_percent = busy.to_f / alive

        threadqueue_length = threadqueue.length

        Monus.write em_threadpool_load: load_percent,
                    em_threadpool_free: free,
                    em_threadpool_busy: busy,
                    em_threadpool_total: total,
                    em_threadpool_alive: alive,
                    em_threadpool_broken: broken,
                    em_threadqueue_length: threadqueue_length
      end
    end
  end

  extend self

  Monus::BuiltInMetric.register :em_threadpool, self
end