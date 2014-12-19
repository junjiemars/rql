(ns jql.core
  (:use [jql.cli])
  (:use [clojure.tools.trace])
  (:gen-class))

(def ^:dynamic
  *current-implementation*)

(def conf "resources/conf.clj")

(defn exit [status message]
  (println message)
  ;(System/exit status)
  )

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (let [options (parse-cli-specs args)]
    (println options)))

(derive ::bash ::common)
(derive ::batch ::common)

(defmulti emit
  (fn [form]
    [*current-implementation* (class form)]))

(defmethod emit
  [::bash clojure.lang.PersistentList]
  [form]
  (case (name (first form))
    "println" (str "echo " (second form))
    nil))

(defmethod emit
  [::batch clojure.lang.PersistentList]
  [form]
  (case (name (first form))
    "println" (str "ECHO " (second form))
    nil))

(defmethod emit
  [::common java.lang.String]
  [form]
  form)

(defmethod emit
  [::common java.lang.Long]
  [form]
  (str form))

(defmethod emit
  [::common java.lang.Double]
  [form]
  (str form))

(defmacro script [form]
  `(emit '~form))


(defmacro with-implementation
  [impl & body]
  `(binding [*current-implementation* ~impl]
     ~@body))

(defn save-conf
  [c m]
  (spit c (pr-str m)))

(defn read-conf
  [c]
  (read-string (slurp c)))


