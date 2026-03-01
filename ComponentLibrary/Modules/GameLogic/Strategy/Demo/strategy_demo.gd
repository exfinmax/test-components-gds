extends PackDemo

func _ready():
	pack_name = "Strategy"
	super._ready()

func _setup_demo() -> void:
	print("\n========== Strategy Demo ==========")
	var q := ProductionQueueComponent.new()
	add_child(q)

	q.job_completed.connect(func(job_id, payload): print("  job_completed: %s" % job_id))

	q.enqueue_job(&"worker",  5.0)
	q.enqueue_job(&"soldier", 8.0)
	q.enqueue_job(&"cannon", 15.0)

	print("  queue_size=%d  is_busy=%s  current=%s" % [
		q.get_queue_size(), q.is_busy(), q.get_current_job_id()])

	# 取消中间任务
	q.cancel_job(&"soldier")
	print("  after cancel soldier: queue_size=%d" % q.get_queue_size())

	q.queue_free()
	print("========== Strategy Demo End ==========\n")

