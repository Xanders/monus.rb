module Monus::BuiltInMetric::EmThreadpool
  def activate
    @interval = Monus.options.dig(:em_threadpool_metric_options, :interval) || 1

    threadpool = nil

    Monus.engine.every @interval do
      threadpool ||= EM.send(:instance_variable_get, :@threadpool)

      if threadpool
        by_status = threadpool.group_by(&:status).transform_values(&:size)

        total = threadpool.size
        run = by_status['run']
        load_percent = run.to_f / total
        broken = total - run - by_status['sleep']

        Monus.write em_threadpool_load: load_percent,
                    em_threadpool_run: run,
                    em_threadpool_total: total,
                    em_threadpool_broken: broken
      end
    end
  end

  extend self

  Monus::BuiltInMetric.register :em_threadpool, self
end