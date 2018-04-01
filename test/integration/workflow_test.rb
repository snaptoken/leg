require "test_helper"

STEP_1 = <<~END
  int main(void) {}
END

STEP_2 = <<~END
  int main(void) {
    return 0;
  }
END

STEP_3 = <<~END
  int main(void) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_4 = <<~END
  #include <stdio.h>

  int main(void) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_2B = <<~END
  int main(int argc, char *argv[]) {
    return 0;
  }
END

STEP_3B = <<~END
  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_4B = <<~END
  #include <stdio.h>

  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }
END

STEP_4C = <<~END
  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }

  // the end
END

STEP_5C = <<~END
  #include <stdio.h>

  int main(int argc, char *argv[]) {
    printf("Hello, world!\\n");

    return 0;
  }

  // the end
END

LITDIFF = <<~END
~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
new file mode 100644
--- /dev/null
+++ b/hello.c
@@ -0,0 +1,1 @@
+int main(void) {}

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -1,1 +1,3 @@
-int main(void) {}
+int main(int argc, char *argv[]) {
+  return 0;
+}

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -1,3 +1,5 @@
|int main(int argc, char *argv[]) {
+  printf("Hello, world!\\n");
+
|  return 0;
|}

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -3,3 +3,5 @@
|
|  return 0;
|}
+
+// the end

~~~ TODO: let user specify commit message
diff --git a/hello.c b/hello.c
--- a/hello.c
+++ b/hello.c
@@ -1,3 +1,5 @@
+#include <stdio.h>
+
|int main(int argc, char *argv[]) {
|  printf("Hello, world!\\n");
|

END

MARKDOWN = <<~END
## 1. TODO: let user specify commit message

```diff
 // hello.c
+int main(void) {}
```

## 2. TODO: let user specify commit message

```diff
 // hello.c
-int main(void) {}
+int main(int argc, char *argv[]) {
+  return 0;
+}
```

## 3. TODO: let user specify commit message

```diff
 // hello.c
 int main(int argc, char *argv[]) {
+  printf("Hello, world!\\n");
+
   return 0;
 }
```

## 4. TODO: let user specify commit message

```diff
 // hello.c
 int main(int argc, char *argv[]) {
   printf("Hello, world!\\n");
 \\
   return 0;
 }
+
+// the end
```

## 5. TODO: let user specify commit message

```diff
 // hello.c
+#include <stdio.h>
+
 int main(int argc, char *argv[]) {
   printf("Hello, world!\\n");
 \\
   return 0;
 }
 \\
 // the end
```


END

MARKDOWN.gsub!(/\\$/, "")

class WorkflowTest < Minitest::Test
  def test_workflow
    Dir.mktmpdir do |dir|
      FileUtils.cd(dir)

      leg_command "init"

      File.write("step/hello.c", STEP_1)
      leg_command "commit"

      File.write("step/hello.c", STEP_2)
      leg_command "commit"

      File.write("step/hello.c", STEP_3)
      leg_command "commit"

      File.write("step/hello.c", STEP_4)
      leg_command "commit"

      leg_command "1"
      assert_equal STEP_1, File.read("step/hello.c")

      leg_command "2"
      assert_equal STEP_2, File.read("step/hello.c")

      leg_command "3"
      assert_equal STEP_3, File.read("step/hello.c")

      leg_command "reset"
      assert_equal STEP_4, File.read("step/hello.c")

      leg_command "2"
      assert_equal STEP_2, File.read("step/hello.c")

      File.write("step/hello.c", STEP_2B)
      leg_command "amend"
      assert_includes File.read("step/hello.c"), "<<<<<<< HEAD"

      File.write("step/hello.c", STEP_3B)
      leg_command "resolve"
      assert_includes File.read("step/hello.c"), "<<<<<<< HEAD"

      File.write("step/hello.c", STEP_4B)
      leg_command "resolve"
      refute_includes File.read("step/hello.c"), "<<<<<<< HEAD"

      leg_command "1"
      assert_equal STEP_1, File.read("step/hello.c")

      leg_command "2"
      assert_equal STEP_2B, File.read("step/hello.c")

      leg_command "3"
      assert_equal STEP_3B, File.read("step/hello.c")

      leg_command "reset"
      assert_equal STEP_4B, File.read("step/hello.c")

      leg_command "3"
      assert_equal STEP_3B, File.read("step/hello.c")

      File.write("step/hello.c", STEP_4C)
      leg_command "commit"
      assert_equal STEP_5C, File.read("step/hello.c")

      assert_equal LITDIFF, File.read("doc/tutorial.litdiff")

      leg_command "build"
      assert File.exists?("build/html/tutorial.html")
      assert_equal MARKDOWN, File.read("build/md/tutorial.md")
    end
  end
end
