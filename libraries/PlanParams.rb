module PlanParams

  # Gets :options from the plan associations and uses it to override default_plan_params
  #
  # @return [Hash] plan_params
  def update_plan_params(plan_params:, opts:)
    if opts.present?
      opts = JSON.parse(opts, { symbolize_names: true })
      plan_params.update(opts)
    end
    plan_params
  end

  #gets the options on the first operaton of a plan
  def get_opts(operations)
    get_op_opts(operations.first)
  end

  #gets the options on a specific operation
  def get_op_opts(op)
    op.plan.associations[:options]
  end

  #sets plan params as a temporary association to the operation under the :plan_params key
  def set_temporary_op_params(op, default_plan_parameters)
      opts = get_op_opts(op)
      op.temporary[:plan_params] = update_plan_params(plan_params: default_plan_params, opts: opts)
  end
  
  # Gets `:options` from the `Plan` associations and the `Operations` and uses 
  # them to override `default_job_params`
  #
  # @param operations [OperationList] the operations
  # @param default_job_params [Hash] the default parameters to be applied to all 
  #   `Operations` in the `Job`
  # @return [Hash] the updated parameters to be applied to all 
  #   `Operations` in the `Job`
  def update_job_params(operations:, default_job_params:)
    opts = operations.first.plan.associations[:options]
    job_params = update_plan_params(plan_params: default_job_params, opts: opts)
    return job_params unless options_for?(operations)

    job_params.keys.each do |key|
      op_vals = operations.map do |op|
        op.input('Options').val.fetch(key, :no_key)
      end

      if op_vals.uniq.length == 1
        job_params[key] = op_vals.first unless op_vals.first == :no_key
      else
        msg = "More than one value given in Operation Options for #{key}:" \
              " #{op_vals}"
        raise IncompatibleParametersError.new(msg)
      end
    end

    job_params
  end

  # Check to see if any of the `Operations` have `Options` set
  #
  def options_for?(operations)
    operations.any? { |op| op.input('Options').try(:val).present? }
  end

  # Gets `Options` from each `Operation` and uses them to update 
  #   `default_operation_params`, then applies the result to each 
  #   `Operation` at `op.temporary[:options]`
  #
  # @param operations [OperationList] the operations
  # @param default_operation_params [Hash] the default parameters to be applied to all 
  #   `Operations` in the `Job`
  def update_operation_params(operations:, default_operation_params:)
    operations.each do |op|
      opts = default_operation_params.dup.update(op.input('Options').val)
      op.temporary[:options] = opts
    end
  end

  class IncompatibleParametersError < StandardError
  
  end
 
end